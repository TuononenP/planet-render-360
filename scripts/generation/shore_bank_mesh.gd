class_name ShoreBankMesh
extends RefCounted

## Joined, zero-overlap retaining faces at the real shoreline. Their
## tops are the same constraints used by the adjoining surface patches.
static func build(root: Node3D, model: ShorelineModel, abort: BuildAbort = null, data: LocationData = null) -> void:
	if model.hard_count() == 0:
		return
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	# A bridge's abutment (ShoreEvidence._abutments) is concrete, as the
	# bridge's own walls are: in the quay's plain render it read as an
	# untextured grey slab under the deck.
	var abut_verts := PackedVector3Array()
	var abut_normals := PackedVector3Array()
	var abut_colors := PackedColorArray()
	var abut_indices := PackedInt32Array()
	var seen := {}
	var m2u := WorldScale.metres_to_units()
	var defenses := SuomenlinnaSite.rings(data.buildings) if data != null else []
	var coping := QuayBuilder.stone_quays(data) or QuayBuilder.granite_quays(data)
	for segment in model.segments:
		if abort != null and abort.requested:
			return
		if str(segment["kind"]) != "hard":
			continue
		var a: Vector2 = segment["a"]
		var b: Vector2 = segment["b"]
		if SuomenlinnaFortress.owns_bank(a, b, defenses):
			continue
		var key := [a, b] if a.x < b.x or (a.x == b.x and a.y < b.y) else [b, a]
		var hash_key := str(key)
		if seen.has(hash_key):
			continue
		seen[hash_key] = true
		var top_a := float(segment["top_a"])
		var top_b := float(segment["top_b"])
		var level_a := float(segment["water_a"])
		var level_b := float(segment["water_b"])
		# A low quay's wall at the water's edge stops at its walk: where the
		# walk lies behind it. The banks beside a quay's end carry its id too
		# (evidence is collected per cell); capped there, the wall stood short
		# of the street behind it, see-through above and black against the
		# far terrain.
		var walk := model.quay_at((a + b) * 0.5 + (segment["land"] as Vector2) * 0.5 * m2u)
		var capped := walk >= 0
		if capped:
			top_a = level_a + float(model.quays[walk]["low"])
			top_b = level_b + float(model.quays[walk]["low"])
		if maxf(top_a - level_a, top_b - level_b) < 0.1:
			continue
		var land: Vector2 = segment["land"]
		var normal := Vector3(-land.x, 0.0, -land.y)
		var face := PackedVector3Array([Vector3(a.x, level_a - 0.6, a.y), Vector3(b.x, level_b - 0.6, b.y),
			Vector3(b.x, top_b, b.y), Vector3(a.x, top_a, a.y)])
		var into_abut := _abutment(segment)
		var coping_min := (1.5 if QuayBuilder.stone_quays(data) else 0.6) * m2u
		var has_coping := coping and not capped and maxf(top_a - level_a, top_b - level_b) > coping_min
		if into_abut:
			_append_face(abut_verts, abut_normals, abut_indices, face, normal, abut_colors,
				WATERLINE_DAMP, Color.WHITE)
		else:
			_append_face(verts, normals, indices, face, normal, colors,
				WATERLINE_DAMP, Color(0.92, 0.92, 0.91) if has_coping else Color.WHITE)
		# A coping along the top of a stone quay wall: the cornice/cap course
		# a masonry quay has, where the face otherwise ran flat into the bank.
		if has_coping:
			if into_abut:
				_coping(abut_verts, abut_normals, abut_indices, a, b, top_a, top_b, normal, abut_colors)
			else:
				_coping(verts, normals, indices, a, b, top_a, top_b, normal, colors)
	var caps := transition_caps(model, abort)
	if abort != null and abort.requested:
		return
	_parapets(model, verts, normals, indices, colors)
	for cap in caps:
		var face: PackedVector3Array = cap["face"]
		var normal: Vector3 = cap["normal"]
		_append_face(verts, normals, indices, face, normal, colors, Color.WHITE, Color.WHITE)
	if not abut_indices.is_empty():
		var abut := TerrainBuilder._add(root, _mesh(abut_verts, abut_normals, abut_indices, abut_colors), abutment_material(data))
		abut.name = "ShoreAbutments"
	if indices.is_empty():
		return
	var node := TerrainBuilder._add(root, _mesh(verts, normals, indices, colors), QuayBuilder.stone_material(data))
	node.name = "ShoreWalls"
	node.set_meta("shore_transitions", caps.size())

static var _abutment_mat: Material = null
## The place-independent concrete bridge deck (RoadBuilder FINISH_HEX
## "deck" never varies by place). The water stage runs before the roads
## stage, so the abutment must use this, never RoadBuilder._mats["deck"]
## — which still holds the previous place's finish then (stone on
## stone-quay places), memoized here for the whole process.
static var _deck_mat: Material = null

static func _concrete_deck_material() -> Material:
	if _deck_mat == null:
		_deck_mat = RoadBuilder._pbr("concrete", RoadBuilder.FINISH_HEX["deck"])
	return _deck_mat

## The bridge deck's concrete (RoadBuilder "deck"), mapped in world space:
## the shore walls carry no UVs.
static func abutment_material(data: LocationData = null) -> Material:
	# Where the bridges are stone (Paris), an abutment is the quay walls' limestone:
	# board-formed concrete read as tan planks against them.
	if QuayBuilder.stone_quays(data):
		return QuayBuilder.stone_material(data)
	if _abutment_mat == null:
		var m := (_concrete_deck_material() as StandardMaterial3D).duplicate() as StandardMaterial3D
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE / WorldScale.metres_to_units()
		_abutment_mat = m
	return _abutment_mat

## True for a bank ShoreEvidence made a bridge's abutment.
static func _abutment(segment: Dictionary) -> bool:
	for source in segment.get("sources", []):
		if str(source).begins_with("abutment:"):
			return true
	return false

## Damp darkened waterline base and dressed granite coping capstone tints (sRGB).
const WATERLINE_DAMP := Color(0.70, 0.71, 0.68)
const COPING_TOP := Color(1.15, 1.14, 1.11)
const COPING_FRONT := Color(1.09, 1.08, 1.06)
const COPING_UNDER := Color(0.62, 0.62, 0.60)

static func _append_face(verts: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array,
		face: PackedVector3Array, normal: Vector3, colors: PackedColorArray = PackedColorArray(),
		c_bottom: Color = Color.WHITE, c_top: Color = Color.WHITE) -> void:
	var k := verts.size()
	verts.append_array(face)
	for i in 4:
		normals.append(normal)
	if colors != null:
		colors.append(c_bottom)
		colors.append(c_bottom)
		colors.append(c_top)
		colors.append(c_top)
	if (face[1] - face[0]).cross(face[2] - face[0]).dot(normal) < 0.0:
		indices.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
	else:
		indices.append_array([k, k + 2, k + 1, k, k + 3, k + 2])

## A wall's coping: a stone course COPING_DEPTH_M deep standing COPING_OUT_M
## proud of the face at its top, as three faces (front, underside, top).
const COPING_DEPTH_M := 0.22
const COPING_OUT_M := 0.12

static func _coping(verts: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array,
		a: Vector2, b: Vector2, top_a: float, top_b: float, normal: Vector3,
		colors: PackedColorArray = PackedColorArray()) -> void:
	var m2u := WorldScale.metres_to_units()
	var out := Vector2(normal.x, normal.z) * COPING_OUT_M * m2u
	var drop := COPING_DEPTH_M * m2u
	var ao := a + out
	var bo := b + out
	_append_face(verts, normals, indices, PackedVector3Array([Vector3(ao.x, top_a - drop, ao.y), Vector3(bo.x, top_b - drop, bo.y),
		Vector3(bo.x, top_b, bo.y), Vector3(ao.x, top_a, ao.y)]), normal, colors, COPING_FRONT, COPING_FRONT)
	_append_face(verts, normals, indices, PackedVector3Array([Vector3(a.x, top_a - drop, a.y), Vector3(b.x, top_b - drop, b.y),
		Vector3(bo.x, top_b - drop, bo.y), Vector3(ao.x, top_a - drop, ao.y)]), Vector3.DOWN, colors, COPING_UNDER, COPING_UNDER)
	_append_face(verts, normals, indices, PackedVector3Array([Vector3(a.x, top_a, a.y), Vector3(b.x, top_b, b.y),
		Vector3(bo.x, top_b, bo.y), Vector3(ao.x, top_a, ao.y)]), Vector3.UP, colors, COPING_TOP, COPING_TOP)

static func _mesh(verts: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array,
		colors: PackedColorArray = PackedColorArray()) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	if colors.size() == verts.size():
		arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

## A low quay's upper wall carries a parapet PARAPET_H_M tall and
## PARAPET_T_M thick on the street's edge (QuayBuilder's, metres).
static func _parapets(model: ShorelineModel, verts: PackedVector3Array, normals: PackedVector3Array,
		indices: PackedInt32Array, colors: PackedColorArray = PackedColorArray()) -> void:
	var m2u := WorldScale.metres_to_units()
	var tall := QuayBuilder.PARAPET_H_M * m2u
	for q: Dictionary in model.quays:
		var wall: PackedVector2Array = q["wall"]
		var land: Vector2 = q["land"]
		var back := land * QuayBuilder.PARAPET_T_M * m2u
		var out := Vector3(-land.x, 0.0, -land.y)
		for i in wall.size() - 1:
			var a := wall[i]
			var b := wall[i + 1]
			if a.distance_squared_to(b) < 0.0001:
				continue
			var ya := model.height(a + land * 0.6 * m2u)
			var yb := model.height(b + land * 0.6 * m2u)
			var a2 := a + back
			var b2 := b + back
			_append_face(verts, normals, indices, PackedVector3Array([Vector3(a.x, ya, a.y), Vector3(b.x, yb, b.y),
				Vector3(b.x, yb + tall, b.y), Vector3(a.x, ya + tall, a.y)]), out, colors)
			_append_face(verts, normals, indices, PackedVector3Array([Vector3(a.x, ya + tall, a.y), Vector3(b.x, yb + tall, b.y),
				Vector3(b2.x, yb + tall, b2.y), Vector3(a2.x, ya + tall, a2.y)]), Vector3.UP, colors, COPING_TOP, COPING_TOP)
			_append_face(verts, normals, indices, PackedVector3Array([Vector3(a2.x, ya, a2.y), Vector3(b2.x, yb, b2.y),
				Vector3(b2.x, yb + tall, b2.y), Vector3(a2.x, ya + tall, a2.y)]), -out, colors)

## A quay can end beside a sloping natural bank. Close the height
## discontinuity with masonry returning landward, using the exact two
## adjoining surface edges. This avoids unsupported terrain curtains.
static func transition_caps(model: ShorelineModel, abort: BuildAbort = null) -> Array:
	var out: Array = []
	_caps(model, out, 1, 0, abort)
	# A low quay's walk (hard 2) meets the street beside it (hard 1): its
	# upper wall and the ends returning to the water.
	_caps(model, out, 2, 1, abort)
	return out

## Caps where triangles of `upper` kind (hard flag at least it: 1 is any
## wall's land, 2 a low quay's walk) share an edge with `lower` kind (the
## exact flag) at another height.
static func _caps(model: ShorelineModel, out: Array, upper: int, lower: int, abort: BuildAbort) -> void:
	var hard_edges := {}
	for patch in model.patches.values():
		if abort != null and abort.requested:
			return
		var triangles: PackedVector3Array = patch["triangles"]
		for i in range(0, triangles.size(), 3):
			if int(patch["owners"][i / 3]) >= 0 or int(patch["hard"][i / 3]) < upper:
				continue
			for edge in 3:
				var a := triangles[i + edge]
				var b := triangles[i + (edge + 1) % 3]
				var key := _edge_key(a, b)
				if hard_edges.has(key):
					hard_edges[key] = null
				else:
					if a.x != key.x or a.z != key.y:
						var swap := a
						a = b
						b = swap
					hard_edges[key] = [a, b, (triangles[i] + triangles[i + 1] + triangles[i + 2]) / 3.0]
	for patch in model.patches.values():
		if abort != null and abort.requested:
			return
		var triangles: PackedVector3Array = patch["triangles"]
		for i in range(0, triangles.size(), 3):
			if int(patch["owners"][i / 3]) >= 0 or int(patch["hard"][i / 3]) != lower:
				continue
			for edge in 3:
				var a := triangles[i + edge]
				var b := triangles[i + (edge + 1) % 3]
				var key := _edge_key(a, b)
				var hard: Variant = hard_edges.get(key)
				if hard == null:
					continue
				hard_edges[key] = null
				if a.x != key.x or a.z != key.y:
					var swap := a
					a = b
					b = swap
				if maxf(absf(a.y - hard[0].y), absf(b.y - hard[1].y)) < 0.01:
					continue
				var outward: Vector3 = (a + b) * 0.5 - hard[2]
				outward.y = 0.0
				outward = outward.normalized()
				_append_cap(out, hard[0], hard[1], a, b, outward)

static func _append_cap(out: Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	var da := a.y - c.y
	var db := b.y - d.y
	if da * db < 0.0:
		# Split where the two surfaces cross rather than emitting a bow tie.
		var t := da / (da - db)
		var mid := a.lerp(b, t)
		_append_cap(out, a, mid, c, mid, normal)
		_append_cap(out, mid, b, mid, d, normal)
		return
	if absf(da) + absf(db) < 0.001:
		return
	out.append({"face": PackedVector3Array([a, b, d, c]), "normal": normal if da + db >= 0.0 else -normal})

static func _edge_key(a: Vector3, b: Vector3) -> Vector4:
	return Vector4(a.x, a.z, b.x, b.z) if a.x < b.x or (a.x == b.x and a.z < b.z) else Vector4(b.x, b.z, a.x, a.z)
