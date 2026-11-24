class_name Lod2MeshBuilder
extends RefCounted

## Builds true 3D CityGML/glTF LoD2 building meshes (Helsinki, Espoo, Turku)
## directly from compact binary PackedInt32Array (.lod2m v2) cells, matching
## standing OSM buildings and suppressing their coarse OSM extrusions.
## Handles N:M relationships cleanly:
##   - Multiple LoD2 buildings inside one large OSM block all build and inherit
##     that block's tags while suppressing the coarse OSM extrusion once.
##   - One large LoD2 building spanning multiple OSM footprints suppresses every
##     overlapping OSM footprint so no procedural wall/roof ever pokes through.

const MAX_MATCH_M := 8.0
## Matches RoofGeometry's 1 UV unit = 20 m convention so MaterialLibrary.ROOF_UV
## (`slate: 8.0`, `terracotta: 4.4`) renders roof tiles at true real-world scale.
const ROOF_UV_PER_M := 0.05

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
	var crs := 1 if TurkuLod2Meshes.is_gk23(data.latitude, data.longitude) \
		else (2 if TurkuLod2Meshes.is_rd_new(data.latitude, data.longitude) else 0)
	var frame := Gk23.frame(data.latitude, data.longitude) if crs == 1 \
		else (RdNew.frame(data.latitude, data.longitude) if crs == 2 else Gk25.frame(data.latitude, data.longitude))
	var default_region := "turku" if crs == 1 else ("amsterdam" if crs == 2 else "helsinki")
	var region := str(ctx.get("region", default_region))
	var fidelity := int(ctx.get("fidelity", 2))
	var eye: Vector2 = ctx.get("eye", Vector2.ZERO)
	var reach: Vector2 = ctx.get("eye_reach", Vector2.ZERO)
	var sea_y := float(ctx.get("sea_y", -INF))
	var tone := float(ctx.get("tone", 0.0))

	# Spatial hash of standing OSM buildings (30 m cells) + precomputed AABBs.
	var grid := {}
	var osm_aabbs: Array[Rect2] = []
	osm_aabbs.resize(sorted.size())
	for k in sorted.size():
		if standing[k] == 0:
			continue
		var b: Dictionary = sorted[k]
		if bool(b.get("mapped_landmark", false)):
			continue
		var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
		var bb := RingGeometry.aabb(ring) if ring.size() >= 3 \
			else Rect2(float(b["x"]) - 4.0 * m2u, float(b["z"]) - 4.0 * m2u, 8.0 * m2u, 8.0 * m2u)
		osm_aabbs[k] = bb
		var gx0 := floori(bb.position.x / 30.0)
		var gx1 := floori(bb.end.x / 30.0)
		var gz0 := floori(bb.position.y / 30.0)
		var gz1 := floori(bb.end.y / 30.0)
		for gx in range(gx0, gx1 + 1):
			for gz in range(gz0, gz1 + 1):
				var ck := Vector2i(gx, gz)
				if not grid.has(ck):
					grid[ck] = []
				(grid[ck] as Array).append(k)

	var batch := MassBatch.new()
	batch.meta = {"lod_layer": "Buildings", "lod2_mesh": true}
	var built := 0
	var enriched := 0

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
			var xz_m := Gk23.frame_xz(frame, ce, cn) if crs == 1 \
				else (RdNew.frame_xz(frame, ce, cn) if crs == 2 else Gk25.frame_xz(frame, ce, cn))
			var cx := xz_m.x * m2u
			var cz := xz_m.y * m2u
			if nwv == 0 or nrv == 0:
				# Attribute-only record (Helsinki): enrich OSM building's roof/wall colour
				# in place and let BuildingBuilder extrude clean vertical walls & manifold roofs.
				var attr_bb := Rect2(cx - 2.0 * m2u, cz - 2.0 * m2u, 4.0 * m2u, 4.0 * m2u)
				var ahits := _find_osm_overlaps(cx, cz, attr_bb, sorted, osm_aabbs, grid, m2u)
				if not ahits.is_empty():
					if _enrich_attrs(sorted[ahits[0]], buf, off):
						enriched += 1
				off += rec_ints
				continue
			var lod_bb := _lod_aabb(buf, off + TurkuLod2Meshes.BLDG_HEADER_INTS, nwv, cx, cz, m2u)
			var hits := _find_osm_overlaps(cx, cz, lod_bb, sorted, osm_aabbs, grid, m2u)
			if not hits.is_empty():
				if _has_rich_osm(hits, sorted):
					if _enrich_attrs(sorted[hits[0]], buf, off):
						enriched += 1
				else:
					var primary_k: int = hits[0]
					var b: Dictionary = sorted[primary_k]
					if _append_building(root, batch, buf, off, b, cx, cz, ground, region, fidelity, eye, reach, sea_y, tone, m2u, ctx):
						for hk: int in hits:
							handled[hk] = 1
						built += 1
			off += rec_ints

	if built > 0:
		batch.commit(root, "Lod2Mesh")
		print("LOD2_MESH built %d true-3D buildings (%d tris)" % [built, batch.triangles])
	if enriched > 0:
		print("LOD2_ATTR enriched %d buildings with sampled roof/wall colours" % enriched)
	return handled

static func _has_rich_osm(hits: Array[int], sorted: Array) -> bool:
	for hk: int in hits:
		var b: Dictionary = sorted[hk]
		if not (b.get("parts", []) as Array).is_empty():
			return true
		if str(b.get("roof_material", "")).strip_edges().to_lower() == "glass":
			return true
		if str(b.get("kind", "")).strip_edges().to_lower() in ["roof", "bridge"]:
			return true
	return false

static func _enrich_attrs(b: Dictionary, buf: PackedInt32Array, off: int) -> bool:
	var changed := false
	var rm := TurkuLod2Meshes.roof_mat_name(buf[off + 6])
	var rc := TurkuLod2Meshes.hex_rgb(buf[off + 7])
	var wm := TurkuLod2Meshes.wall_mat_name(buf[off + 8])
	var wc := TurkuLod2Meshes.hex_rgb(buf[off + 9])
	if rc != "" and str(b.get("roof_colour", "")) == "":
		b["roof_colour"] = rc
		changed = true
	if rm != "" and str(b.get("roof_material", "")) == "":
		b["roof_material"] = rm
		changed = true
	if wc != "" and str(b.get("colour", "")) == "":
		b["colour"] = wc
		changed = true
	if wm != "" and str(b.get("material", "")) == "":
		b["material"] = wm
		changed = true
	return changed

static func _lod_aabb(buf: PackedInt32Array, wv_off: int, nwv: int, cx: float, cz: float, m2u: float) -> Rect2:
	if nwv <= 0:
		return Rect2(cx - 2.0 * m2u, cz - 2.0 * m2u, 4.0 * m2u, 4.0 * m2u)
	var s := 0.01 * m2u
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for i in nwv:
		var vi := wv_off + i * 3
		var x := cx + float(buf[vi]) * s
		var z := cz + float(buf[vi + 2]) * s
		if x < min_x: min_x = x
		if x > max_x: max_x = x
		if z < min_z: min_z = z
		if z > max_z: max_z = z
	return Rect2(min_x, min_z, maxf(0.1, max_x - min_x), maxf(0.1, max_z - min_z))

## Returns standing OSM indices overlapping this LoD2 building, with the best
## primary match first (centroid inside OSM footprint, else nearest within MAX_MATCH_M).
## Every other OSM building whose centroid lies inside `lod_bb` (or whose footprint
## encloses `(cx, cz)`) is also returned so it is suppressed with zero z-fighting.
static func _find_osm_overlaps(cx: float, cz: float, lod_bb: Rect2, sorted: Array,
		osm_aabbs: Array[Rect2], grid: Dictionary, m2u: float) -> Array[int]:
	var pt := Vector2(cx, cz)
	var max_d := MAX_MATCH_M * m2u
	var gx0 := floori((lod_bb.position.x - max_d) / 30.0)
	var gx1 := floori((lod_bb.end.x + max_d) / 30.0)
	var gz0 := floori((lod_bb.position.y - max_d) / 30.0)
	var gz1 := floori((lod_bb.end.y + max_d) / 30.0)
	var seen := {}
	var best_k := -1
	var best_score := INF
	var overlaps: Array[int] = []
	var inner_bb := lod_bb.grow(-0.6 * m2u)
	for gx in range(gx0, gx1 + 1):
		for gz in range(gz0, gz1 + 1):
			var bucket: Variant = grid.get(Vector2i(gx, gz))
			if bucket == null:
				continue
			for k: int in (bucket as Array):
				if seen.has(k):
					continue
				seen[k] = true
				var obb: Rect2 = osm_aabbs[k]
				if not obb.intersects(lod_bb.grow(max_d)):
					continue
				var b: Dictionary = sorted[k]
				var b_pt := Vector2(float(b["x"]), float(b["z"]))
				var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
				var inside_osm := ring.size() >= 3 and obb.has_point(pt) and Geometry2D.is_point_in_polygon(pt, ring)
				var osm_in_lod := inner_bb.has_point(b_pt)
				var dist := pt.distance_to(b_pt)
				# Only true geometric overlaps suppress secondary OSM buildings;
				# dist <= max_d is used solely as a fallback for choosing primary_k.
				if inside_osm or osm_in_lod:
					overlaps.append(k)
				if inside_osm or osm_in_lod or dist <= max_d:
					var score := (0.0 if inside_osm else (25.0 if osm_in_lod else 50.0)) + dist
					if score < best_score:
						best_score = score
						best_k = k
	if best_k < 0:
		return []
	if overlaps.is_empty() or overlaps[0] != best_k:
		overlaps.erase(best_k)
		overlaps.push_front(best_k)
	return overlaps

static func _append_building(root: Node3D, batch: MassBatch, buf: PackedInt32Array, off: int,
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
	if ring.size() >= 3:
		BuildingFoundation.plinth(root, ring, [], footing, ground, false)
		BuildingFoundation.build(root, ring, [], footing, b_eff, ground)

	var look_ctx := ctx.duplicate()
	if not look_ctx.has("region"):
		look_ctx["region"] = region
	if not look_ctx.has("density"):
		look_ctx["density"] = "urban"
	b_eff["x"] = cx
	b_eff["z"] = cz
	var look := BuildingHeights._look_for(b_eff, look_ctx)
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
	var est_fh := rec_h / float(storeys)
	var floor_h := clampf(minf(float(look.get("floor_h", 3.2)), est_fh), 2.5, 3.8)

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

	var blank_mat := FacadeMaterials.blank_for_facade(facade)
	var walls := Lod2WallLayout.decode(buf, wv_off, wi_off, nwv, nwi, cx, floor_y, cz,
		m2u, bay_m, bays, floor_h, sink, blank_mat != null)
	var w_tint := (WallVariety.tint_for(cx, cz, batch.chroma, batch.tone) * batch.wall_vt) \
		if WallVariety.is_wall(facade) else Color.WHITE
	var win_arr: Array = walls["windowed"]
	if not (win_arr[0] as PackedVector3Array).is_empty():
		var cols := PackedColorArray()
		cols.resize((win_arr[0] as PackedVector3Array).size())
		cols.fill(w_tint)
		batch.add_group(cell_key, facade, win_arr[0], win_arr[1], win_arr[2], cols, win_arr[3])
	var blank_arr: Array = walls["blank"]
	if not (blank_arr[0] as PackedVector3Array).is_empty():
		var cols := PackedColorArray()
		cols.resize((blank_arr[0] as PackedVector3Array).size())
		cols.fill(w_tint)
		batch.add_group(cell_key, blank_mat if blank_mat != null else facade,
			blank_arr[0], blank_arr[1], blank_arr[2], cols, blank_arr[3])

	var r_arr := _decode_surface(buf, rv_off, ru_off, ri_off, nrv, nri, cx, floor_y, cz, m2u, ROOF_UV_PER_M, ROOF_UV_PER_M, 0.0)
	if not (r_arr[0] as PackedVector3Array).is_empty():
		batch.add(cell_key, roof_mat, r_arr[0], r_arr[1], r_arr[2], r_arr[3])

	return true

static func _decode_surface(buf: PackedInt32Array, v_off: int, u_off: int, i_off: int,
		n_verts: int, n_idx: int, ox: float, oy: float, oz: float, m2u: float, u_scale: float,
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
		if i0 < 0 or i0 >= n_verts or i1 < 0 or i1 >= n_verts or i2 < 0 or i2 >= n_verts:
			continue
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
		var dv_sink := (sink_u / m2u) * v_scale if sink_u > 0.0 else 0.0
		uvs[out_i] = Vector2(float(buf[u0]) * us, float(buf[u0 + 1]) * vs + (dv_sink if buf[v_off + i0 * 3 + 1] <= 40 else 0.0))
		uvs[out_i + 1] = Vector2(float(buf[u1]) * us, float(buf[u1 + 1]) * vs + (dv_sink if buf[v_off + i1 * 3 + 1] <= 40 else 0.0))
		uvs[out_i + 2] = Vector2(float(buf[u2]) * us, float(buf[u2 + 1]) * vs + (dv_sink if buf[v_off + i2 * 3 + 1] <= 40 else 0.0))
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
