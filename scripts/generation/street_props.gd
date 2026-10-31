class_name StreetProps
extends RefCounted

## Street furniture + linear barriers (T5.1/T7.2, PRD §3.4 props).
## * Lampposts: only along real OSM carriageways in built-up blocks
##   (lit streets), every 25 m alternating sides on the verge, never in
##   a footprint / carriageway / water. Regional style: cast-iron lantern
##   (Paris + historic European cores) or modern arm luminaire. Instanced
##   (MultiMesh per style). Radius per preset: Fast none, Balanced
##   120 m, High 220 m, Ultra 600 m.
## * Barriers: real OSM barrier=wall/city_wall/retaining_wall (stone
##   PBR), fence/railing/guard_rail (alpha-tested picket panels on
##   posts), hedge (leaf-textured clipped hedge) — draped on GroundTruth,
##   merged into one mesh per kind. Absent in data → absent in the world.
## Benches/street furniture nodes are not in the OSM payload yet (gap).

const LAMP_SPACING_M := 25.0
const PROP_R := [0.0, 120.0, 220.0, 600.0]
const LIT := ["primary", "secondary", "tertiary", "residential", "unclassified",
	"living_street", "pedestrian", "trunk", "primary_link", "secondary_link",
	"tertiary_link"]
const MAJOR := ["primary", "secondary", "trunk", "primary_link", "secondary_link"]
const LANTERN_REGIONS := ["haussmann", "france", "central_europe", "west_europe_brick", "alpine"]
## barrier class → [kind, height m, thickness m]
const BARRIERS := {
	"wall": ["wall", 1.8, 0.4], "city_wall": ["wall", 6.0, 1.6],
	"retaining_wall": ["wall", 1.2, 0.5], "fence": ["fence", 1.5, 0.05],
	"railing": ["fence", 1.1, 0.05], "guard_rail": ["fence", 0.8, 0.05],
	"handrail": ["fence", 1.0, 0.05], "hedge": ["hedge", 1.4, 0.9],
}

static var _lamp_meshes: Dictionary = {}
static var _fence_tex: Texture2D
static var _mats: Dictionary = {}

static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, ctx: Dictionary) -> Dictionary:
	var lamps := _lampposts(root, data, ground, mask, ctx)
	var bar := _barriers(root, data, ground, ctx)
	return {"lamps": lamps, "barrier_m": bar}

# --- Lampposts -----------------------------------------------------------

static func _lampposts(root: Node3D, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, ctx: Dictionary) -> int:
	var radius_m: float = PROP_R[int(ctx["preset"])]
	if radius_m <= 0.0 or data.buildings.is_empty():
		return 0
	var m2u: float = ctx["m2u"]
	var r_u := radius_m * m2u
	var region := ArchitectureStyle.country_region_for(data.latitude, data.longitude)
	var lantern_region := region in LANTERN_REGIONS
	var placed := {"lantern": [], "modern": [], "modern_s": []}
	var occupied := {}
	var occ_cell := 10.0 * m2u
	for r in data.roads:
		var pts: PackedVector2Array
		var cls := "residential"
		var width_m := 6.0
		if r is Dictionary:
			var rd: Dictionary = r
			if bool(rd.get("tunnel", false)) or bool(rd.get("bridge", false)):
				continue
			pts = rd.get("points", PackedVector2Array())
			cls = str(rd.get("class", "residential"))
			width_m = float(rd.get("width_m", 6.0))
		elif r is PackedVector2Array:
			pts = r
		else:
			continue
		if cls not in LIT or pts.size() < 2:
			continue
		var style := "lantern" if lantern_region and (region == "haussmann" or cls not in MAJOR) \
			else ("modern" if cls in MAJOR else "modern_s")
		var off := (width_m * 0.5 + 1.1) * m2u
		var step := LAMP_SPACING_M * m2u
		var carry := step * 0.5
		var side := 1.0
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var seg := a.distance_to(b)
			if seg < 0.001:
				continue
			var dir := (b - a) / seg
			var nrm := Vector2(-dir.y, dir.x)
			var t := carry
			while t < seg:
				var c := a + dir * t
				t += step
				side = -side
				var p := c + nrm * off * side
				if p.length() > r_u or mask.built_fraction(p.x, p.y) < 0.04:
					continue
				if mask.blocked(p.x, p.y, VegetationMask.BUILDING | VegetationMask.ROAD
						| VegetationMask.WATER, 0.0) or ground.water_at(p.x, p.y) > 0.0:
					continue
				var ok := Vector2i(int(floor(p.x / occ_cell)), int(floor(p.y / occ_cell)))
				if occupied.has(ok):
					continue
				occupied[ok] = true
				var toward := -nrm * side
				var yaw := atan2(-toward.y, toward.x)
				var h := 1.0 if style != "modern_s" else 0.75
				var basis := Basis(Vector3.UP, yaw).scaled(Vector3(m2u, m2u * h, m2u))
				(placed[style] as Array).append(Transform3D(basis,
					Vector3(p.x, ground.height_at_world(p.x, p.y), p.y)))
			carry = t - seg
	var total := 0
	for style in placed:
		var xf: Array = placed[style]
		if xf.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _lamp_mesh("lantern" if style == "lantern" else "modern")
		mm.instance_count = xf.size()
		for k in xf.size():
			mm.set_instance_transform(k, xf[k])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.name = "Prop_lamp_%s" % style
		root.add_child(mmi)
		total += xf.size()
	return total

## Lamp meshes in metres: metal surface + emissive glass surface.
static func _lamp_mesh(style: String) -> ArrayMesh:
	if _lamp_meshes.has(style):
		return _lamp_meshes[style]
	var metal := TreeMeshLibrary.Buf.new()
	var glass := TreeMeshLibrary.Buf.new()
	var metal_col: Color
	var glass_col: Color
	if style == "lantern":
		metal_col = Color(0.11, 0.14, 0.12)
		glass_col = Color(1.0, 0.86, 0.62)
		# Plinth, fluted shaft, collar, lantern housing + cap + finial.
		TreeMeshLibrary._tube(metal, [Vector3(0, -0.3, 0), Vector3(0, 0.55, 0)], [0.2, 0.17], 8, 0.8, 1.0)
		TreeMeshLibrary._tube(metal, [Vector3(0, 0.55, 0), Vector3(0, 0.75, 0)], [0.17, 0.08], 8, 0.9, 1.0)
		TreeMeshLibrary._tube(metal, [Vector3(0, 0.75, 0), Vector3(0, 3.7, 0)], [0.075, 0.055], 8, 0.9, 1.0)
		TreeMeshLibrary._tube(metal, [Vector3(0, 3.7, 0), Vector3(0, 3.85, 0)], [0.1, 0.12], 8, 1.0, 1.0)
		TreeMeshLibrary._tube(glass, [Vector3(0, 3.85, 0), Vector3(0, 4.45, 0)], [0.13, 0.27], 4, 1.0, 1.0)
		TreeMeshLibrary._tube(metal, [Vector3(0, 4.45, 0), Vector3(0, 4.7, 0)], [0.32, 0.05], 4, 1.0, 1.0)
		TreeMeshLibrary._tube(metal, [Vector3(0, 4.7, 0), Vector3(0, 4.9, 0)], [0.04, 0.01], 6, 1.0, 1.0)
	else:
		metal_col = Color(0.42, 0.44, 0.46)
		glass_col = Color(1.0, 0.97, 0.9)
		TreeMeshLibrary._tube(metal, [Vector3(0, -0.3, 0), Vector3(0, 0.4, 0)], [0.13, 0.12], 8, 0.8, 1.0)
		TreeMeshLibrary._tube(metal, [Vector3(0, 0.4, 0), Vector3(0, 7.6, 0)], [0.1, 0.06], 8, 0.9, 1.0)
		var arm: Array = TreeMeshLibrary._bezier(Vector3(0, 7.5, 0), Vector3(0.1, 8.2, 0), Vector3(1.6, 8.15, 0), 5)
		TreeMeshLibrary._tube(metal, arm, [0.06, 0.055, 0.05, 0.05, 0.045, 0.045], 6, 1.0, 1.0)
		_box(metal, Vector3(1.85, 8.2, 0), Vector3(0.75, 0.12, 0.3))
		_box(glass, Vector3(1.85, 8.12, 0), Vector3(0.62, 0.04, 0.22))
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, metal.arrays())
	var mm := StandardMaterial3D.new()
	mm.albedo_color = metal_col
	mm.metallic = 0.55
	mm.roughness = 0.42
	mm.vertex_color_use_as_albedo = true
	m.surface_set_material(0, mm)
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, glass.arrays())
	var gm := StandardMaterial3D.new()
	gm.albedo_color = glass_col
	gm.emission_enabled = true
	gm.emission = glass_col
	gm.emission_energy_multiplier = 1.4
	gm.roughness = 0.15
	m.surface_set_material(1, gm)
	_lamp_meshes[style] = m
	return m

## Axis-aligned box (6 outward faces, clockwise-front).
static func _box(b: TreeMeshLibrary.Buf, c: Vector3, size: Vector3) -> void:
	var h := size * 0.5
	var faces := [
		[Vector3.UP, Vector3(1, 0, 0), Vector3(0, 0, 1)],
		[Vector3.DOWN, Vector3(1, 0, 0), Vector3(0, 0, -1)],
		[Vector3.RIGHT, Vector3(0, 0, 1), Vector3(0, 1, 0)],
		[Vector3.LEFT, Vector3(0, 0, -1), Vector3(0, 1, 0)],
		[Vector3.BACK, Vector3(-1, 0, 0), Vector3(0, 1, 0)],
		[Vector3.FORWARD, Vector3(1, 0, 0), Vector3(0, 1, 0)],
	]
	for f in faces:
		var n: Vector3 = f[0]
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var fc := c + n * h
		var uu := u * h
		var vv := v * h
		var cs := [fc - uu + vv, fc + uu + vv, fc + uu - vv, fc - uu - vv]
		TreeMeshLibrary._card(b, cs, [n, n, n, n], [1.0, 1.0, 1.0, 1.0])

# --- Barriers ------------------------------------------------------------

static func _barriers(root: Node3D, data: LocationData, ground: GroundTruth,
		ctx: Dictionary) -> float:
	if data.barriers.is_empty():
		return 0.0
	var m2u: float = ctx["m2u"]
	var bufs := {"wall": TreeMeshLibrary.Buf.new(), "fence": TreeMeshLibrary.Buf.new(),
		"hedge": TreeMeshLibrary.Buf.new(), "hedge_core": TreeMeshLibrary.Buf.new()}
	var total_m := 0.0
	var piece := 3.0 * m2u
	for br in data.barriers:
		if not (br is Dictionary):
			continue
		var row: Array = BARRIERS.get(str((br as Dictionary).get("class", "")), [])
		if row.is_empty():
			continue
		var kind: String = row[0]
		var hgt := float(row[1]) * m2u
		var thick := float(row[2]) * m2u
		var pts: PackedVector2Array = (br as Dictionary).get("points", PackedVector2Array())
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var seg := a.distance_to(b)
			var nseg := maxi(int(ceil(seg / piece)), 1)
			for k in nseg:
				var p0 := a.lerp(b, float(k) / float(nseg))
				var p1 := a.lerp(b, float(k + 1) / float(nseg))
				if not ground.is_inside(p0.x, p0.y) or ground.water_at(p0.x, p0.y) > 0.0 \
						or ground.water_at(p1.x, p1.y) > 0.0:
					continue
				var y0 := ground.height_at_world(p0.x, p0.y)
				var y1 := ground.height_at_world(p1.x, p1.y)
				total_m += p0.distance_to(p1) / m2u
				match kind:
					"wall":
						_wall_piece(bufs["wall"], p0, p1, y0, y1, hgt, thick, 0.3 * m2u, m2u)
					"fence":
						_fence_piece(bufs["fence"], p0, p1, y0, y1, hgt, m2u)
					"hedge":
						_wall_piece(bufs["hedge_core"], p0, p1, y0, y1, hgt * 0.9, thick * 0.8, 0.1 * m2u, m2u)
						_wall_piece(bufs["hedge"], p0, p1, y0, y1, hgt, thick, 0.1 * m2u, m2u)
	var season: int = ctx["season"]
	var mats := {
		"wall": MaterialLibrary.pbr_material("stone", Color(0.92, 0.9, 0.86), 1.0),
		"fence": _fence_material(),
		"hedge": TreeMeshLibrary.leaf_material("broad", TreeSpecies.tint("oak", mini(season, 2)) * 0.85, 0.0, 0.0, true),
		"hedge_core": _core_material(),
	}
	for kind in bufs:
		var buf: TreeMeshLibrary.Buf = bufs[kind]
		if buf.idx.is_empty():
			continue
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, buf.arrays())
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.material_override = mats[kind]
		mi.name = "Prop_barrier_%s" % kind
		root.add_child(mi)
	return total_m

## Draped box piece a→b: two sides + top (+ end caps), UVs in metres/2.
static func _wall_piece(b: TreeMeshLibrary.Buf, p0: Vector2, p1: Vector2, y0: float,
		y1: float, h: float, t: float, sink: float, m2u: float) -> void:
	var d := (p1 - p0)
	var ln := d.length()
	if ln < 0.0001:
		return
	var n2 := Vector2(-d.y, d.x) / ln * t * 0.5
	var n3 := Vector3(n2.x, 0, n2.y).normalized()
	var a := Vector3(p0.x, y0 - sink, p0.y)
	var c := Vector3(p1.x, y1 - sink, p1.y)
	var up := Vector3(0, h + sink, 0)
	var o := Vector3(n2.x, 0, n2.y)
	var u1 := ln / m2u / 2.0
	var v1 := (h + sink) / m2u / 2.0
	var uvs := [Vector2(0, 0), Vector2(u1, 0), Vector2(u1, v1), Vector2(0, v1)]
	TreeMeshLibrary._card(b, [a + o + up, c + o + up, c + o, a + o], [n3, n3, n3, n3], [1.0, 1.0, 0.75, 0.75], uvs)
	TreeMeshLibrary._card(b, [c - o + up, a - o + up, a - o, c - o], [-n3, -n3, -n3, -n3], [1.0, 1.0, 0.75, 0.75], uvs)
	var tu := t / m2u / 2.0
	TreeMeshLibrary._card(b, [a - o + up, c - o + up, c + o + up, a + o + up],
		[Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP], [1.0, 1.0, 1.0, 1.0],
		[Vector2(0, 0), Vector2(u1, 0), Vector2(u1, tu), Vector2(0, tu)])

## Fence piece: one double-sided picket panel card + a post at p0.
static func _fence_piece(b: TreeMeshLibrary.Buf, p0: Vector2, p1: Vector2, y0: float,
		y1: float, h: float, m2u: float) -> void:
	var ln := p0.distance_to(p1)
	if ln < 0.0001:
		return
	var d := (p1 - p0) / ln
	var n3 := Vector3(-d.y, 0, d.x)
	var a := Vector3(p0.x, y0, p0.y)
	var c := Vector3(p1.x, y1, p1.y)
	var up := Vector3(0, h, 0)
	var u1 := ln / m2u / 1.5
	TreeMeshLibrary._card(b, [a + up, c + up, c, a], [n3, n3, n3, n3], [1.0, 1.0, 0.8, 0.8],
		[Vector2(0, 0), Vector2(u1, 0), Vector2(u1, 1), Vector2(0, 1)])

static func _core_material() -> StandardMaterial3D:
	if not _mats.has("core"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.12, 0.18, 0.08)
		m.roughness = 0.95
		_mats["core"] = m
	return _mats["core"]

static func _fence_material() -> StandardMaterial3D:
	if _mats.has("fence"):
		return _mats["fence"]
	if _fence_tex == null:
		# 1.5 m panel: top + bottom rail, a post, pickets every ~12 cm.
		var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var col := Color(0.16, 0.17, 0.17, 1.0)
		img.fill_rect(Rect2i(0, 6, 128, 7), col)
		img.fill_rect(Rect2i(0, 112, 128, 7), col)
		img.fill_rect(Rect2i(0, 0, 9, 128), col)
		for x in range(15, 128, 11):
			img.fill_rect(Rect2i(x, 2, 3, 124), col)
		img.generate_mipmaps()
		_fence_tex = ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = _fence_tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.metallic = 0.5
	m.roughness = 0.5
	_mats["fence"] = m
	return m
