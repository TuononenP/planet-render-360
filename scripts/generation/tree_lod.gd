class_name TreeLod
extends RefCounted

## Tree LOD assignment around an eye, re-runnable at runtime
## (TreeLodWindow) so the trees around a walking or teleported camera
## are full meshes, not the build eye's far-ring impostors.
##
## Each tree's transform and tint never depend on its LOD, so they are
## computed once per build into one packed row per tree, in MultiMesh
## buffer layout (3x4 transform rows, then colour). Assigning LODs
## around an eye is then a sort and a regroup over packed arrays (pure:
## safe on a worker thread), and emitting is one buffer write per
## species/LOD/sector group.

const ROW := 16
## Name of the node holding the tree MultiMeshes and the "tree_lod"
## state (one node, so flat adoption into the world keeps the meta).
const SET_NAME := "VegTreeSet"

## LOD-independent instancing state for a VegetationBuilder plan.
static func state(plan: Dictionary, ctx: Dictionary) -> Dictionary:
	var pos: Array = plan["pos"]
	var sps: Array = plan["sp"]
	var scl: Array = plan["scale"]
	var m2u: float = ctx["m2u"]
	var season: int = ctx["season"]
	var names := PackedStringArray()
	var spi := PackedInt32Array()
	var sector := PackedByteArray()
	var p3 := PackedVector3Array()
	var rows := PackedFloat32Array()
	var n := pos.size()
	spi.resize(n)
	sector.resize(n)
	p3.resize(n)
	rows.resize(n * ROW)
	for i in n:
		var sp := str(sps[i])
		var k := names.find(sp)
		if k < 0:
			k = names.size()
			names.append(sp)
		spi[i] = k
		var p: Vector3 = pos[i]
		p3[i] = p
		sector[i] = int(floor((atan2(p.z, p.x) + PI) / TAU * float(VegetationBuilder.SECTORS))) \
			% VegetationBuilder.SECTORS
		var h1 := VegetationBuilder._hash(p.x, p.z, 11.0)
		var h2 := VegetationBuilder._hash(p.x, p.z, 12.0)
		var h3 := VegetationBuilder._hash(p.x, p.z, 13.0)
		var hv := float(TreeSpecies.spec(sp).get("h_var", 0.2))
		var sc: Vector2 = scl[i]
		var sy := sc.x * (1.0 + (h1 - 0.5) * 2.0 * hv)
		var sxz := sy * sc.y * (0.9 + h2 * 0.2)
		var basis := Basis(Vector3.UP, h3 * TAU)
		var tilt_axis := Vector3(cos(h1 * 9.0), 0, sin(h1 * 9.0))
		basis = Basis(tilt_axis, (h2 - 0.5) * 0.06) * basis
		basis = basis.scaled(Vector3(sxz, sy, sxz) * m2u)
		var c := VegetationBuilder._instance_tint(sp, season, h1, h2, h3)
		var o := i * ROW
		rows[o] = basis.x.x
		rows[o + 1] = basis.y.x
		rows[o + 2] = basis.z.x
		rows[o + 3] = p.x
		rows[o + 4] = basis.x.y
		rows[o + 5] = basis.y.y
		rows[o + 6] = basis.z.y
		rows[o + 7] = p.y
		rows[o + 8] = basis.x.z
		rows[o + 9] = basis.y.z
		rows[o + 10] = basis.z.z
		rows[o + 11] = p.z
		rows[o + 12] = c.r
		rows[o + 13] = c.g
		rows[o + 14] = c.b
		rows[o + 15] = c.a
	return {"pos": p3, "spi": spi, "sector": sector, "names": names, "rows": rows,
		"full_u": float(ctx["full_r"]) * m2u, "mid_u": float(ctx["mid_r"]) * m2u,
		"budget": int(ctx["budget"]), "cap": int(ctx["budget"]) * VegetationBuilder.IMPOSTOR_FACTOR,
		"season": season, "snow": float(ctx["snow"]), "sway": float(ctx["sway"])}

## LODs around `eye` (world XZ units): nearest first, LOD 0/1 by ring
## and demoted to impostors past the mesh budget, impostors past their
## cap dropped. Returns {"groups": {key: [buffer, origins, count]},
## "lod": [n0, n1, n2], "dropped": n, "eye": eye}; key = "sp|lod|sector".
## Touches only packed arrays: safe on a worker thread.
static func assign(st: Dictionary, eye: Vector2) -> Dictionary:
	var pos: PackedVector3Array = st["pos"]
	var spi: PackedInt32Array = st["spi"]
	var sector: PackedByteArray = st["sector"]
	var names: PackedStringArray = st["names"]
	var rows: PackedFloat32Array = st["rows"]
	var full_u: float = st["full_u"]
	var mid_u: float = st["mid_u"]
	var budget: int = st["budget"]
	var cap: int = st["cap"]
	var n := pos.size()
	# Sort by distance natively: distance (1/16 unit steps) in the high
	# bits, index in the low 24.
	var keys := PackedInt64Array()
	keys.resize(n)
	for i in n:
		var p := pos[i]
		var d := Vector2(p.x, p.z).distance_to(eye)
		keys[i] = (mini(int(d * 16.0), 0x3fffffff) << 24) | i
	keys.sort()
	var members := {}
	var lod_counts := [0, 0, 0]
	var mesh_trees := 0
	var imp_trees := 0
	var dropped := 0
	for key in keys:
		var i := key & 0xffffff
		# Exact distance for the ring test (the key is quantized).
		var p := pos[i]
		var d := Vector2(p.x, p.z).distance_to(eye)
		var lod := 0 if d <= full_u else (1 if d <= mid_u else 2)
		if lod < 2 and mesh_trees >= budget:
			lod = 2
		if lod == 2 and imp_trees >= cap:
			dropped += 1
			continue
		if lod < 2:
			mesh_trees += 1
		else:
			imp_trees += 1
		lod_counts[lod] += 1
		var g := (spi[i] * 3 + lod) * VegetationBuilder.SECTORS + sector[i]
		if not members.has(g):
			members[g] = []
		(members[g] as Array).append(i)
	var groups := {}
	for g in members:
		var ids: Array = members[g]
		var buf := PackedFloat32Array()
		var origins := PackedVector3Array()
		for i in ids:
			buf.append_array(rows.slice(i * ROW, i * ROW + ROW))
			origins.append(pos[i])
		var s := int(g) % VegetationBuilder.SECTORS
		var lod := (int(g) / VegetationBuilder.SECTORS) % 3
		var sp := names[int(g) / VegetationBuilder.SECTORS / 3]
		groups["%s|%d|%d" % [sp, lod, s]] = [buf, origins, ids.size()]
	return {"groups": groups, "lod": lod_counts, "dropped": dropped, "eye": eye}

## Replaces `tree_set`'s tree MultiMeshes with an assignment's groups (main
## thread). Returns the number of nodes. `preset` >= 0 also applies the
## LodRing vegetation range to the new nodes (runtime swaps; a build
## gets its ranges from LodRing.apply over the whole world).
static func emit(tree_set: Node3D, st: Dictionary, a: Dictionary, preset: int = -1) -> int:
	for c in tree_set.get_children():
		tree_set.remove_child(c)
		c.queue_free()
	var nodes := 0
	var groups: Dictionary = a["groups"]
	for key in groups:
		var parts: PackedStringArray = (key as String).split("|")
		var sp := parts[0]
		var lod := int(parts[1])
		var g: Array = groups[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = TreeMeshLibrary.mesh(sp, lod, int(st["season"]), float(st["snow"]), float(st["sway"]))
		mm.instance_count = int(g[2])
		mm.buffer = g[0]
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.name = "VegTrees_%s_lod%d_s%s" % [sp, lod, parts[2]]
		# Trunk-base origins for tests/captures (headless MultiMesh
		# storage is a dummy that keeps no transforms).
		mmi.set_meta("origins", g[1])
		if lod == 2:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tree_set.add_child(mmi)
		if preset >= 0:
			LodRing.apply_vegetation(mmi, preset)
		nodes += 1
	tree_set.set_meta("tree_eye", a["eye"])
	return nodes
