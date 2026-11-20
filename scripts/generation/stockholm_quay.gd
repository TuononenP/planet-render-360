class_name StockholmQuay
extends RefCounted

## Stockholm's granite quay walls (Riddarholmen, Slussen, Skeppsbron) read as
## a pale flat slab with a plain face: the real walls are dressed ashlar with a
## dark, wet, weed-stained course at the waterline, a coping, and a band of
## granite setts laid along the quay top. This adds the two bands to every hard
## bank ShoreBankMesh walled: the waterline course (two surfaces: the algae
## foot and the wet granite over it) a hair proud of the face, and the sett
## strip lying on the quay edge behind the coping. Stockholm only.

## Wall foot and the courses' heights over the water, metres.
const FOOT_M := 0.6
const WEED_TOP_M := 0.18
const WET_TOP_M := 0.55
## Courses stand this far proud of the face, metres.
const OUT_M := 0.025
## Width of the sett strip behind the coping, and its lift over the quay top.
const SETT_W_M := 1.5
const SETT_LIFT_M := 0.02
## The ground behind the wall may differ from the quay top by this much for the strip to lie.
const SETT_FLOAT_M := 0.2
## A wall shorter than this (over the water) gets no courses.
const MIN_WALL_M := 0.3
## A wall at Slussen (lock chambers, island, basins) taller than SILL_MIN_M is battered into steps: a pale cut-granite sill
## SILL_W_M wide just over the water, then courses stepping back (each at most
## STEP_MAX_M high) up to the wall, a dark joint line along the sill. Those walls
## also carry a finer ashlar skin (LOCK_COURSE_M courses) a hair proud of the face.
const SILL_MIN_M := 1.2
const SILL_AT_M := 0.35
const SILL_W_M := 1.4
const STEP_MAX_M := 1.8
const JOINT_M := 0.09
## Transition caps (masonry returning where a quay meets lower ground, ShoreBankMesh) at
## Slussen are battered too, up to this height; taller are hillside, left alone.
const CAP_MAX_M := 12.0
const LOCK_COURSE_M := 0.3
const SKIN_M := 0.012

## One sett texture tile, metres, and its cobbles per side.
const SETT_TILE_M := 1.2
const SETT_N := 8

static var _materials := {}

static func applies(data: LocationData) -> bool:
	return ShoreApron.stockholm(data) and QuayBuilder.granite_quays(data)

## Adds the waterline courses and the sett strips; returns the walls covered.
static func build(root: Node3D, model: ShorelineModel, data: LocationData, abort: BuildAbort = null) -> int:
	if not applies(data) or model == null or model.hard_count() == 0:
		return 0
	var m2u := WorldScale.metres_to_units()
	var weed := _Surface.new()
	var wet := _Surface.new()
	var sett := _Surface.new()
	var sill := _Surface.new()
	var joint := _Surface.new()
	var skin := _Surface.new()
	var sills := 0
	var slussen := StockholmShore._xz_box(data, StockholmShore.SLUSSEN)
	var seen := {}
	var count := 0
	for segment in model.segments:
		if abort != null and abort.requested:
			return count
		if str(segment["kind"]) != "hard" or ShoreBankMesh._abutment(segment):
			continue
		var a: Vector2 = segment["a"]
		var b: Vector2 = segment["b"]
		var key := str([a, b]) if a.x < b.x or (a.x == b.x and a.y < b.y) else str([b, a])
		if seen.has(key):
			continue
		seen[key] = true
		var land: Vector2 = segment["land"]
		var level_a := float(segment["water_a"])
		var level_b := float(segment["water_b"])
		var top_a := float(segment["top_a"])
		var top_b := float(segment["top_b"])
		# A low quay's wall at the water stops at its walk (ShoreBankMesh).
		var walk := model.quay_at((a + b) * 0.5 + land * 0.5 * m2u)
		if walk >= 0:
			top_a = level_a + float(model.quays[walk]["low"])
			top_b = level_b + float(model.quays[walk]["low"])
		if maxf(top_a - level_a, top_b - level_b) < MIN_WALL_M * m2u:
			continue
		var out := -land * OUT_M * m2u
		var ao := a + out
		var bo := b + out
		var normal := Vector3(-land.x, 0.0, -land.y)
		# Never past the top of a short wall.
		var w_a := minf(WEED_TOP_M * m2u, (top_a - level_a) * 0.4)
		var w_b := minf(WEED_TOP_M * m2u, (top_b - level_b) * 0.4)
		var t_a := minf(WET_TOP_M * m2u, (top_a - level_a) * 0.6)
		var t_b := minf(WET_TOP_M * m2u, (top_b - level_b) * 0.6)
		var foot := FOOT_M * m2u
		weed.face(PackedVector3Array([Vector3(ao.x, level_a - foot, ao.y), Vector3(bo.x, level_b - foot, bo.y),
			Vector3(bo.x, level_b + w_b, bo.y), Vector3(ao.x, level_a + w_a, ao.y)]), normal)
		var oo := out * 1.6
		wet.face(PackedVector3Array([Vector3(a.x + oo.x, level_a + w_a, a.y + oo.y), Vector3(b.x + oo.x, level_b + w_b, b.y + oo.y),
			Vector3(b.x + oo.x, level_b + t_b, b.y + oo.y), Vector3(a.x + oo.x, level_a + t_a, a.y + oo.y)]), normal)
		var body := int(segment.get("body", -1))
		# Every wall at Slussen: the chambers' and the island's between them and the
		# basins' (those rings belong to bodies the lock marking does not reach).
		var at_slussen := slussen.has_point((a + b) * 0.5) or (body >= 0 and body < model.domains.bodies.size() \
			and bool(model.domains.bodies[body].get("lock_site", false)))
		if at_slussen:
			_lock_wall(skin, sill, joint, a, b, land, level_a, level_b, top_a, top_b, m2u)
			if minf(top_a - level_a, top_b - level_b) > SILL_MIN_M * m2u:
				sills += 1
		# The sett strip behind the coping, on the quay top; where the ground behind
		# the wall falls away (a bank, a lock's slope) a strip would float: none.
		var back := land * SETT_W_M * m2u
		var lift := SETT_LIFT_M * m2u
		if absf(model.height(a + back) - top_a) > SETT_FLOAT_M * m2u or absf(model.height(b + back) - top_b) > SETT_FLOAT_M * m2u:
			count += 1
			continue
		sett.face(PackedVector3Array([Vector3(a.x, top_a + lift, a.y), Vector3(b.x, top_b + lift, b.y),
			Vector3(b.x + back.x, top_b + lift, b.y + back.y), Vector3(a.x + back.x, top_a + lift, a.y + back.y)]), Vector3.UP)
		count += 1
	# The caps: the island's and the basins' masonry that is no shore segment.
	var caps := 0
	for cap: Dictionary in ShoreBankMesh.transition_caps(model, abort):
		var f: PackedVector3Array = cap["face"]
		var mid := Vector2((f[0].x + f[1].x + f[2].x + f[3].x) * 0.25, (f[0].z + f[1].z + f[2].z + f[3].z) * 0.25)
		if not slussen.has_point(mid):
			continue
		var n3: Vector3 = cap["normal"]
		var low_a := minf(f[0].y, f[3].y)
		var low_b := minf(f[1].y, f[2].y)
		var high_a := maxf(f[0].y, f[3].y)
		var high_b := maxf(f[1].y, f[2].y)
		var h := minf(high_a - low_a, high_b - low_b) / m2u
		if h <= 0.05 or h > CAP_MAX_M:
			continue
		_lock_wall(skin, sill, joint, Vector2(f[0].x, f[0].z), Vector2(f[1].x, f[1].z), -Vector2(n3.x, n3.z).normalized(),
			low_a, low_b, high_a, high_b, m2u)
		caps += 1
		if h > SILL_MIN_M:
			sills += 1
	if count == 0 and caps == 0:
		return 0
	var mesh := ArrayMesh.new()
	for part: Array in [[weed, "weed"], [wet, "wet"], [sett, "sett"], [sill, "sill"], [joint, "joint"], [skin, "lockwall"]]:
		var surface: _Surface = part[0]
		if surface.indices.is_empty():
			continue
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface.arrays())
		mesh.surface_set_material(mesh.get_surface_count() - 1, material(str(part[1])))
	var node := MeshInstance3D.new()
	node.name = "StockholmQuay"
	node.set_meta("sills", sills)
	node.set_meta("caps", caps)
	node.mesh = mesh
	root.add_child(node)
	return count

## The battered face of a lock wall `h` metres over the water: [height over the
## water of each step's top, metres out from the face], sill first, then courses
## stepping back; no run between two tops (nor the last to the wall top) over STEP_MAX_M.
static func tier_plan(h: float) -> Array:
	var out: Array = [[SILL_AT_M, SILL_W_M]]
	if h <= SILL_MIN_M:
		return out
	var n := clampi(ceili((h - SILL_AT_M) / STEP_MAX_M) - 1, 1, 6)
	for k in range(1, n + 1):
		out.append([SILL_AT_M + (h - SILL_AT_M) * float(k) / float(n + 1), SILL_W_M * (1.0 - float(k) / float(n + 1))])
	return out

## One lock wall segment: the fine ashlar skin, and (over SILL_MIN_M) the stepped
## granite courses with the dark joint line along the sill.
static func _lock_wall(skin: _Surface, sill: _Surface, joint: _Surface, a: Vector2, b: Vector2, land: Vector2,
		level_a: float, level_b: float, top_a: float, top_b: float, m2u: float) -> void:
	var normal := Vector3(-land.x, 0.0, -land.y)
	var out := -land * m2u
	var s := out * SKIN_M
	skin.face(PackedVector3Array([Vector3(a.x + s.x, level_a - FOOT_M * m2u, a.y + s.y), Vector3(b.x + s.x, level_b - FOOT_M * m2u, b.y + s.y),
		Vector3(b.x + s.x, top_b, b.y + s.y), Vector3(a.x + s.x, top_a, a.y + s.y)]), normal)
	var h := minf(top_a - level_a, top_b - level_b) / m2u
	if h <= SILL_MIN_M:
		return
	var plan := tier_plan(h)
	var below := -0.4
	for i in plan.size():
		var up: float = plan[i][0]
		var o: float = plan[i][1]
		var inner: float = plan[i + 1][1] if i + 1 < plan.size() else 0.0
		var po := out * o
		var pi := out * inner
		var ya := level_a + up * m2u
		var yb := level_b + up * m2u
		var prev_up: float = plan[i - 1][0] if i > 0 else below
		var ba := level_a + prev_up * m2u
		var bb := level_b + prev_up * m2u
		# The tread (top) between this step's front and the next one in, and its riser.
		sill.face(PackedVector3Array([Vector3(a.x + po.x, ya, a.y + po.y), Vector3(b.x + po.x, yb, b.y + po.y),
			Vector3(b.x + pi.x, yb, b.y + pi.y), Vector3(a.x + pi.x, ya, a.y + pi.y)]), Vector3.UP)
		sill.face(PackedVector3Array([Vector3(a.x + po.x, ba, a.y + po.y), Vector3(b.x + po.x, bb, b.y + po.y),
			Vector3(b.x + po.x, yb, b.y + po.y), Vector3(a.x + po.x, ya, a.y + po.y)]), normal)
		if i == 0:
			# Dark joints: along the sill's front edge and where it meets the wall.
			var fj := out * (o - JOINT_M)
			var bj := out * JOINT_M
			var lift := 0.004 * m2u
			joint.face(PackedVector3Array([Vector3(a.x + po.x, ya + lift, a.y + po.y), Vector3(b.x + po.x, yb + lift, b.y + po.y),
				Vector3(b.x + fj.x, yb + lift, b.y + fj.y), Vector3(a.x + fj.x, ya + lift, a.y + fj.y)]), Vector3.UP)
			joint.face(PackedVector3Array([Vector3(a.x + bj.x, ya + lift, a.y + bj.y), Vector3(b.x + bj.x, yb + lift, b.y + bj.y),
				Vector3(b.x, yb + lift, b.y), Vector3(a.x, ya + lift, a.y)]), Vector3.UP)

class _Surface:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	## A quad, wound so its front faces `normal` (clockwise seen from there).
	func face(corners: PackedVector3Array, normal: Vector3) -> void:
		ShoreBankMesh._append_face(verts, normals, indices, corners, normal)

	func arrays() -> Array:
		var out: Array = []
		out.resize(Mesh.ARRAY_MAX)
		out[Mesh.ARRAY_VERTEX] = verts
		out[Mesh.ARRAY_NORMAL] = normals
		out[Mesh.ARRAY_INDEX] = indices
		return out

## The three surfaces' materials, world-mapped (the faces carry no UVs).
static func material(kind: String) -> StandardMaterial3D:
	if _materials.has(kind):
		return _materials[kind]
	var m := StandardMaterial3D.new()
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	var m2u := WorldScale.metres_to_units()
	match kind:
		"weed":
			# Algae and mussel foot: near black, green-brown.
			m.albedo_color = Color(0.085, 0.10, 0.075)
			m.roughness = 0.55
			m.albedo_texture = _ashlar_texture(Color(0.7, 0.75, 0.62))
			m.uv1_scale = Vector3.ONE / (QuayBuilder.ASHLAR_COURSE_M * QuayBuilder.ASHLAR_TILE_COURSES * m2u)
		"wet":
			# The same granite wet: darker and glossier than the dry face.
			m.albedo_color = Color(0.19, 0.19, 0.185)
			m.roughness = 0.38
			m.albedo_texture = _ashlar_texture(Color(0.8, 0.8, 0.78))
			m.uv1_scale = Vector3.ONE / (QuayBuilder.ASHLAR_COURSE_M * QuayBuilder.ASHLAR_TILE_COURSES * m2u)
		"sill":
			# Pale cut granite.
			m.albedo_texture = _ashlar_texture(Color(0.85, 0.87, 0.89))
			m.albedo_color = Color(0.92, 0.94, 0.96)
			m.roughness = 0.8
			m.uv1_scale = Vector3.ONE / (QuayBuilder.ASHLAR_COURSE_M * QuayBuilder.ASHLAR_TILE_COURSES * m2u)
		"joint":
			m.albedo_color = Color(0.03, 0.03, 0.035)
			m.roughness = 0.95
		"lockwall":
			# Finer ashlar than the shared 0.45 m courses: 0.3 m, cool grey.
			m.albedo_texture = QuayBuilder._ashlar_material(Color(0.62, 0.66, 0.70), LOCK_COURSE_M, 0.2).albedo_texture
			m.albedo_color = Color(0.55, 0.58, 0.62)
			m.roughness = 0.9
			m.uv1_scale = Vector3.ONE / (LOCK_COURSE_M * QuayBuilder.ASHLAR_TILE_COURSES * m2u)
		_:
			m.albedo_texture = sett_texture()
			# The texture runs up to white: tinted to the quay's granite grey.
			m.albedo_color = Color(0.42, 0.41, 0.39)
			m.roughness = 0.88
			m.uv1_scale = Vector3.ONE / (SETT_TILE_M * m2u)
	_materials[kind] = m
	return m

static func _ashlar_texture(base: Color) -> Texture2D:
	return QuayBuilder._ashlar_material(base, 0.45, 0.18).albedo_texture

## Granite setts: rows of small blocks, staggered, each its own grey with a
## warm or cool cast, dark joints; the tile repeats every SETT_TILE_M.
static func sett_texture() -> Texture2D:
	var n := 128
	var cell := n / SETT_N
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	for y in n:
		var row := y / cell
		var shift := (cell / 2) if row % 2 == 1 else 0
		for x in n:
			var col := ((x + shift) % n) / cell
			var h := fposmod(sin(float(row * 17 + col * 31) * 12.9898) * 43758.5453, 1.0)
			var warm := fposmod(h * 5.3, 1.0)
			var tone := 0.62 + 0.38 * h
			var grain := fposmod(sin(float(x * 29 + y * 13) * 78.233) * 43758.5453, 1.0)
			tone *= 0.94 + 0.12 * grain
			var c := Color(tone * (0.97 + 0.06 * warm), tone * 0.98, tone * (1.0 - 0.05 * warm + 0.02))
			var edge_x := ((x + shift) % cell)
			var edge_y := y % cell
			var joint := minf(float(mini(edge_x, cell - 1 - edge_x)), float(mini(edge_y, cell - 1 - edge_y)))
			if joint < 1.0:
				c *= 0.45
			elif joint < 2.0:
				c *= 0.8
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
