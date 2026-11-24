class_name Lod2MeshBuilder
extends RefCounted

## Builds true 3D CityGML/glTF LoD2 building meshes (Helsinki, Espoo, Turku)
## directly from compact binary PackedInt32Array (.lod2m v2) cells, matching
## standing OSM buildings and suppressing their coarse OSM extrusions.
## Wall and roof surfaces are batched into MassBatch by material with true-metre
## UVs so FacadeMaterials + FacadeShader (Ultra interior rooms, glass reflections,
## night windows, roof snow) apply identically to procedural buildings.

const MAX_MATCH_M := 22.0
const MAX_AREA_RATIO := 4.5
const ROOF_UV_PER_M := 0.25

static func build_corridor(root: Node3D, data: LocationData, ground: GroundTruth,
		sorted: Array, standing: PackedByteArray, ctx: Dictionary) -> PackedByteArray:
	var handled := PackedByteArray()
	handled.resize(sorted.size())
	if data == null or sorted.is_empty():
		return handled
	if not TurkuLod2Meshes.covers(data.latitude, data.longitude):
		return handled
	var cell_bufs := TurkuLod2Meshes.cells_for(data.latitude, data.longitude)
	if cell_bufs.is_empty():
		return handled

	var m2u := WorldScale.metres_to_units()
	var use_gk23 := TurkuLod2Meshes.is_gk23(data.latitude, data.longitude)
	var frame := Gk23.frame(data.latitude, data.longitude) if use_gk23 else Gk25.frame(data.latitude, data.longitude)
	var region := str(ctx.get("region", "turku" if use_gk23 else "helsinki"))
	var fidelity := int(ctx.get("fidelity", 2))
	var eye: Vector2 = ctx.get("eye", Vector2.ZERO)
	var reach: Vector2 = ctx.get("eye_reach", Vector2.ZERO)
	var sea_y := float(ctx.get("sea_y", -INF))
	var tone := float(ctx.get("tone", 0.0))

	# Spatial hash of standing OSM buildings (30 m cells) for O(1) matching.
	var grid := {}
	for k in sorted.size():
		if standing[k] == 0:
			continue
		var b: Dictionary = sorted[k]
		if bool(b.get("mapped_landmark", false)):
			continue
		var ck := Vector2i(floori(float(b["x"]) / 30.0), floori(float(b["z"]) / 30.0))
		if not grid.has(ck):
			grid[ck] = []
		(grid[ck] as Array).append(k)

	var batch := MassBatch.new()
	batch.meta = {"lod_layer": "Buildings", "lod2_mesh": true}
	var built := 0

	for buf: PackedInt32Array in cell_bufs:
		var count := buf[2]
		var off := TurkuLod2Meshes.HEADER_INTS
		for _bi in count:
			if off + TurkuLod2Meshes.BLDG_HEADER_INTS > buf.size():
				break
			var nwv := buf[off + 10]
			var nwi := buf[off + 11]
			var nrv := buf[off + 12]
			var nri := buf[off + 13]
			var rec_ints := TurkuLod2Meshes.BLDG_HEADER_INTS + nwv * 5 + nwi + nrv * 5 + nri
			if off + rec_ints > buf.size():
				break
			var ce := float(buf[off]) * 0.1
			var cn := float(buf[off + 1]) * 0.1
			var lod_area := float(buf[off + 2]) * 0.1
			var xz_m := Gk23.frame_xz(frame, ce, cn) if use_gk23 else Gk25.frame_xz(frame, ce, cn)
			var cx := xz_m.x * m2u
			var cz := xz_m.y * m2u
			var k := _find_osm_match(cx, cz, lod_area, sorted, handled, grid, m2u)
			if k >= 0:
				var b: Dictionary = sorted[k]
				if _append_building(batch, buf, off, b, cx, cz, ground, region, fidelity, eye, reach, sea_y, tone, m2u, ctx):
					handled[k] = 1
					built += 1
			off += rec_ints

	if built > 0:
		batch.commit(root, "Lod2Mesh")
		print("LOD2_MESH built %d true-3D buildings (%d tris)" % [built, batch.triangles])
	return handled

static func _find_osm_match(cx: float, cz: float, lod_area: float, sorted: Array,
		handled: PackedByteArray, grid: Dictionary, m2u: float) -> int:
	var gx := floori(cx / 30.0)
	var gz := floori(cz / 30.0)
	var best_k := -1
	var best_score := INF
	var max_d := MAX_MATCH_M * m2u
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			var bucket: Variant = grid.get(Vector2i(gx + dx, gz + dz))
			if bucket == null:
				continue
			for k: int in (bucket as Array):
				if handled[k] != 0:
					continue
				var b: Dictionary = sorted[k]
				var dist := Vector2(cx - float(b["x"]), cz - float(b["z"])).length()
				if dist > max_d:
					continue
				var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
				var osm_area := absf(RingGeometry.signed_area(ring)) / (m2u * m2u) if ring.size() >= 3 else 0.0
				if osm_area > 4.0 and lod_area > 4.0:
					var ratio := maxf(osm_area, lod_area) / minf(osm_area, lod_area)
					if ratio > MAX_AREA_RATIO:
						continue
				if dist < best_score:
					best_score = dist
					best_k = k
	return best_k

static func _append_building(batch: MassBatch, buf: PackedInt32Array, off: int,
		b: Dictionary, cx: float, cz: float, ground: GroundTruth, region: String,
		fidelity: int, eye: Vector2, reach: Vector2, sea_y: float, tone: float,
		m2u: float, ctx: Dictionary) -> bool:
	var nwv := buf[off + 10]
	var nwi := buf[off + 11]
	var nrv := buf[off + 12]
	var nri := buf[off + 13]
	if nwv < 3 or nwi < 3 or nrv < 3 or nri < 3:
		return false

	var lod_area := float(buf[off + 2]) * 0.1
	var rec_h := maxf(float(buf[off + 3]) * 0.01, 2.5)
	var storeys := maxi(1, buf[off + 4])
	var start_yr := buf[off + 5]
	var rm := TurkuLod2Meshes.roof_mat_name(buf[off + 6])
	var rc := TurkuLod2Meshes.hex_rgb(buf[off + 7])
	var wm := TurkuLod2Meshes.wall_mat_name(buf[off + 8])
	var wc := TurkuLod2Meshes.hex_rgb(buf[off + 9])

	# Merge sampled roof & wall attributes without clobbering explicit OSM / Notable tags.
	var b_eff := b.duplicate()
	if rc != "" and str(b_eff.get("roof_colour", "")) == "":
		b_eff["roof_colour"] = rc
	if rm != "" and str(b_eff.get("roof_material", "")) == "":
		b_eff["roof_material"] = rm
	if wc != "" and str(b_eff.get("colour", "")) == "":
		b_eff["colour"] = wc
	if wm != "" and str(b_eff.get("material", "")) == "":
		b_eff["material"] = wm
	if start_yr >= 1700 and int(b_eff.get("start_year", 0)) <= 0:
		b_eff["start_year"] = start_yr

	var centre := Vector2(cx, cz)
	var seed_v := TerrainBuilder._hash(cx, cz)
	var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
	var footing := BuildingFoundation.sample(ground, ring, centre, sea_y) \
		if ring.size() >= 3 else {"floor": ground.height_at_world(cx, cz), "raised": false}
	var sink := 0.0 if bool(footing["raised"]) else BuildingFoundation.SINK_M * m2u
	var floor_y := float(footing["floor"])

	var look := ArchitectureStyle.resolve(b_eff, region, str(ctx.get("density", "urban")),
		seed_v, lod_area)
	var eye_d := BuildingBuilder.eye_dist(centre, eye, reach)
	var distant := minf(eye_d, centre.length()) / m2u > MaterialLibrary.full_detail_radius_m(fidelity)

	var facade := FacadeMaterials.facade_for_building(b_eff, region, storeys,
		fidelity, distant, seed_v, look)
	var shape := str(b_eff.get("roof_shape", "gabled"))
	if shape == "":
		shape = "gabled"
	var roof_mat := FacadeMaterials.roof_for_building(b_eff, region, shape,
		Color(0, 0, 0, 0), fidelity, distant, seed_v, look)

	var uvp := FacadeMaterials.facade_uv(facade)
	var bay_m := maxf(uvp.x, 2.2)
	var bays := maxf(uvp.y, 4.0)
	var u_scale := 1.0 / (bay_m * bays)
	var est_fh := rec_h / float(storeys)
	var floor_h := clampf(minf(float(look.get("floor_h", 3.2)), est_fh), 2.5, 3.8)
	var v_scale := 1.0 / floor_h

	var cell_key := "%d,%d" % [floori(cx / LodRing.MERGE_CELL_M), floori(cz / LodRing.MERGE_CELL_M)]
	batch.chroma = float(look.get("vt", 0.0))
	batch.tone = tone
	batch.wall_vt = FacadeMaterials.wall_residual(facade, b_eff, look, seed_v) if distant else Color.WHITE
	batch.roof_vt = FacadeMaterials.roof_residual(roof_mat, b_eff, look, Color(0, 0, 0, 0)) if distant else Color.WHITE

	var wv_off := off + TurkuLod2Meshes.BLDG_HEADER_INTS
	var wu_off := wv_off + nwv * 3
	var wi_off := wu_off + nwv * 2
	var rv_off := wi_off + nwi
	var ru_off := rv_off + nrv * 3
	var ri_off := ru_off + nrv * 2

	var w_arr := _decode_surface(buf, wv_off, wu_off, wi_off, nwi, cx, floor_y, cz, m2u, u_scale, v_scale, sink)
	if not (w_arr[0] as PackedVector3Array).is_empty():
		batch.add(cell_key, facade, w_arr[0], w_arr[1], w_arr[2], w_arr[3])

	var r_arr := _decode_surface(buf, rv_off, ru_off, ri_off, nri, cx, floor_y, cz, m2u, ROOF_UV_PER_M, ROOF_UV_PER_M, 0.0)
	if not (r_arr[0] as PackedVector3Array).is_empty():
		batch.add(cell_key, roof_mat, r_arr[0], r_arr[1], r_arr[2], r_arr[3])

	return true

static func _decode_surface(buf: PackedInt32Array, v_off: int, u_off: int, i_off: int,
		n_idx: int, ox: float, oy: float, oz: float, m2u: float, u_scale: float,
		v_scale: float, sink_u: float) -> Array:
	var n_tri := n_idx / 3
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	verts.resize(n_tri * 3)
	norms.resize(n_tri * 3)
	uvs.resize(n_tri * 3)
	indices.resize(n_tri * 3)
	var out_i := 0
	var s := 0.01 * m2u
	var us := 0.01 * u_scale
	var vs := 0.01 * v_scale
	for t in n_tri:
		var bi := i_off + t * 3
		var i0 := buf[bi]
		var i1 := buf[bi + 1]
		var i2 := buf[bi + 2]
		var p0 := _pt(buf, v_off + i0 * 3, ox, oy, oz, s, sink_u)
		var p1 := _pt(buf, v_off + i1 * 3, ox, oy, oz, s, sink_u)
		var p2 := _pt(buf, v_off + i2 * 3, ox, oy, oz, s, sink_u)
		var n := (p2 - p0).cross(p1 - p0)
		var nl := n.length()
		if nl < 1e-6:
			continue
		n /= nl
		verts[out_i] = p0
		verts[out_i + 1] = p1
		verts[out_i + 2] = p2
		norms[out_i] = n
		norms[out_i + 1] = n
		norms[out_i + 2] = n
		var u0 := u_off + i0 * 2
		var u1 := u_off + i1 * 2
		var u2 := u_off + i2 * 2
		uvs[out_i] = Vector2(float(buf[u0]) * us, float(buf[u0 + 1]) * vs)
		uvs[out_i + 1] = Vector2(float(buf[u1]) * us, float(buf[u1 + 1]) * vs)
		uvs[out_i + 2] = Vector2(float(buf[u2]) * us, float(buf[u2 + 1]) * vs)
		indices[out_i] = out_i
		indices[out_i + 1] = out_i + 1
		indices[out_i + 2] = out_i + 2
		out_i += 3
	if out_i < verts.size():
		verts.resize(out_i)
		norms.resize(out_i)
		uvs.resize(out_i)
		indices.resize(out_i)
	return [verts, norms, uvs, indices]

static func _pt(buf: PackedInt32Array, vi: int, ox: float, oy: float, oz: float, s: float, sink_u: float) -> Vector3:
	var y_cm := float(buf[vi + 1])
	var y := oy + y_cm * s
	if sink_u > 0.0 and y_cm <= 40.0:
		y -= sink_u
	return Vector3(ox + float(buf[vi]) * s, y, oz + float(buf[vi + 2]) * s)
