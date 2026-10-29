class_name TreeImpostor
extends RefCounted

## Far-ring impostor textures (T5.1/T7.2): the species' LOD-0 mesh is
## software-rasterised orthographically (side view, z-buffered, texel-
## sampled leaf atlas + bark), so the cross-card silhouette is the real
## tree's. Packed channels, read by TreeMeshLibrary.IMPOSTOR_SHADER:
##   R = luminance (texture x baked AO), G = foliage (1) vs bark (0),
##   B = up-facing foliage (snow mask), A = coverage.
## Season tint stays a material uniform, so one texture serves all
## seasons (deciduous winter has its own bare texture).
## tools/gen_foliage_textures.gd bakes them at 256x512 into
## assets/textures/foliage/; missing files are painted at runtime at
## quarter resolution.

const SIZE := Vector2i(256, 512)

static var _tex: Dictionary = {}

static func file_name(sp: String, bare: bool) -> String:
	return "imp_%s%s.png" % [sp, "_bare" if bare else ""]

static func texture(sp: String, bare: bool) -> Texture2D:
	var key := file_name(sp, bare)
	if _tex.has(key):
		return _tex[key]
	var img: Image = null
	var path := FoliageTextures.DIR + key
	if FileAccess.file_exists(path):
		img = Image.load_from_file(path)
	if img == null or img.is_empty():
		img = paint(sp, bare, 0.25)
	img.convert(Image.FORMAT_RGBA8)
	img.generate_mipmaps()
	FoliageTextures.preserve_coverage(img, 0.5)
	var t := ImageTexture.create_from_image(img)
	_tex[key] = t
	return t

## Rasterise the LOD-0 tree into a packed impostor image.
static func paint(sp: String, bare: bool, res: float = 1.0) -> Image:
	var ss := 2 if res >= 0.5 else 1
	var w := int(float(SIZE.x) * res) * ss
	var h := int(float(SIZE.y) * res) * ss
	var box := TreeMeshLibrary.bounds(sp, bare)
	var half := maxf(maxf(absf(box.position.x), absf(box.end.x)),
		maxf(absf(box.position.z), absf(box.end.z)))
	var y0 := box.position.y
	var y1 := box.end.y
	var s := TreeSpecies.spec(sp)
	var bufs: Array = TreeMeshLibrary.bufs(sp, 0, bare)
	var leaf_kind := "twigs" if bare else str(s["leaf"])
	var leaf_img := FoliageTextures.leaf(leaf_kind).get_image()
	if leaf_img.is_compressed():
		leaf_img.decompress()
	leaf_img.clear_mipmaps()
	var bark_img := FoliageTextures.bark_albedo(str(s["bark"])).get_image()
	bark_img.clear_mipmaps()
	var bark_lum := (TreeSpecies.BARK_TINT.get(str(s["bark"]), Color(0.4, 0.35, 0.3)) as Color).get_luminance()
	var px := PackedFloat32Array()
	px.resize(w * h * 4)
	var depth := PackedFloat32Array()
	depth.resize(w * h)
	depth.fill(-INF)
	for i in w * h:
		px[i * 4] = 0.6
		px[i * 4 + 1] = 1.0
	for surf in 2:
		var b: TreeMeshLibrary.Buf = bufs[surf]
		var img := bark_img if surf == 0 else leaf_img
		var iw := img.get_width()
		var ih := img.get_height()
		var tri := 0
		while tri < b.idx.size():
			var ia := b.idx[tri]
			var ib := b.idx[tri + 1]
			var ic := b.idx[tri + 2]
			tri += 3
			var va := b.verts[ia]
			var vb := b.verts[ib]
			var vc := b.verts[ic]
			var pa := Vector2((va.x + half) / (2.0 * half) * w, (y1 - va.y) / (y1 - y0) * h)
			var pb := Vector2((vb.x + half) / (2.0 * half) * w, (y1 - vb.y) / (y1 - y0) * h)
			var pc := Vector2((vc.x + half) / (2.0 * half) * w, (y1 - vc.y) / (y1 - y0) * h)
			var area := (pb - pa).cross(pc - pa)
			if absf(area) < 0.01:
				continue
			var minx := maxi(int(floor(minf(pa.x, minf(pb.x, pc.x)))), 0)
			var maxx := mini(int(ceil(maxf(pa.x, maxf(pb.x, pc.x)))), w - 1)
			var miny := maxi(int(floor(minf(pa.y, minf(pb.y, pc.y)))), 0)
			var maxy := mini(int(ceil(maxf(pa.y, maxf(pb.y, pc.y)))), h - 1)
			var ua := b.uvs[ia]
			var ub := b.uvs[ib]
			var uc := b.uvs[ic]
			var aoa := b.colors[ia].r
			var aob := b.colors[ib].r
			var aoc := b.colors[ic].r
			var up := (b.normals[ia].y + b.normals[ib].y + b.normals[ic].y) / 3.0
			for y in range(miny, maxy + 1):
				for x in range(minx, maxx + 1):
					var p := Vector2(float(x) + 0.5, float(y) + 0.5)
					var l0 := (pc - pb).cross(p - pb) / area
					var l1 := (pa - pc).cross(p - pc) / area
					var l2 := 1.0 - l0 - l1
					if l0 < 0.0 or l1 < 0.0 or l2 < 0.0:
						continue
					var z := va.z * l0 + vb.z * l1 + vc.z * l2
					var di := y * w + x
					if z <= depth[di]:
						continue
					var uv := ua * l0 + ub * l1 + uc * l2
					var tx := posmod(int(uv.x * float(iw)), iw)
					var ty := posmod(int(uv.y * float(ih)), ih)
					var c := img.get_pixel(tx, ty)
					if surf == 1 and c.a < 0.5:
						continue
					var ao := aoa * l0 + aob * l1 + aoc * l2
					depth[di] = z
					var o := di * 4
					if surf == 0:
						px[o] = clampf(ao * c.get_luminance() / maxf(bark_lum, 0.05) * 0.8, 0.0, 1.0)
						px[o + 1] = 0.0
						px[o + 2] = 0.0
					else:
						px[o] = clampf(ao * c.g, 0.0, 1.0)
						px[o + 1] = 0.0 if bare else 1.0
						px[o + 2] = smoothstep(0.2, 0.7, up)
					px[o + 3] = 1.0
	var bytes := PackedByteArray()
	bytes.resize(w * h * 4)
	for i in px.size():
		bytes[i] = clampi(int(px[i] * 255.0), 0, 255)
	var out := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, bytes)
	if ss > 1:
		out.resize(w / ss, h / ss, Image.INTERPOLATE_BILINEAR)
	return out
